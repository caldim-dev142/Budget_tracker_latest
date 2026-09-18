import { Injectable, OnModuleInit, UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth, DecodedIdToken } from 'firebase-admin/auth';
import { OAuth2Client } from 'google-auth-library';

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private readonly googleClient = new OAuth2Client();

  /// Allow-list of OAuth client IDs accepted by the direct-Google fallback.
  ///
  /// SECURITY: google-auth-library skips the `aud` check entirely when no
  /// audience is supplied, which would make *any* Google-signed ID token from
  /// *any* unrelated application valid here — an account-takeover vector.
  /// The fallback therefore stays DISABLED unless this list is configured.
  private googleAudiences: string[] = [];

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    this.googleAudiences = (this.config.get<string>('GOOGLE_OAUTH_CLIENT_IDS') ?? '')
      .split(',')
      .map((id) => id.trim())
      .filter((id) => id.length > 0);

    if (this.googleAudiences.length === 0) {
      this.logger.warn(
        'GOOGLE_OAUTH_CLIENT_IDS is not set — the direct-Google ID token fallback is disabled. ' +
          'Only Firebase-issued ID tokens will be accepted.',
      );
    }

    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
    let privateKey = this.config.get<string>('FIREBASE_PRIVATE_KEY');

    if (privateKey) {
      privateKey = privateKey.replace(/\\n/g, '\n');
    }

    if (getApps().length > 0) {
      return;
    }

    if (projectId && clientEmail && privateKey) {
      try {
        initializeApp({
          credential: cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        this.logger.log(`Firebase Admin initialized with service account cert for project: ${projectId}`);
      } catch (error) {
        this.logger.error('Failed to initialize Firebase Admin SDK with service account cert', error);
      }
    } else if (projectId) {
      try {
        initializeApp({ projectId });
        this.logger.log(`Firebase Admin initialized with projectId: ${projectId}`);
      } catch (error) {
        this.logger.error('Failed to initialize Firebase Admin SDK with projectId', error);
      }
    } else {
      this.logger.warn(
        'Firebase Admin environment variable FIREBASE_PROJECT_ID is missing.',
      );
    }
  }

  async verifyIdToken(idToken: string): Promise<DecodedIdToken> {
    if (!idToken || typeof idToken !== 'string' || idToken.trim().length === 0) {
      throw new UnauthorizedException('Missing or invalid token');
    }

    // 1. Try Firebase Admin token verification without checkRevoked to avoid requiring GCP metadata server
    if (getApps().length > 0) {
      try {
        const decodedToken = await getAuth().verifyIdToken(idToken, false);
        // SECURITY: no hardcoded project-id default — an unset FIREBASE_PROJECT_ID
        // must fail closed rather than silently validate against a baked-in constant.
        const expectedProjectId = this.config.get<string>('FIREBASE_PROJECT_ID');

        if (!expectedProjectId) {
          this.logger.error('FIREBASE_PROJECT_ID is not configured — refusing to accept Firebase ID token.');
          throw new UnauthorizedException('Server authentication is not correctly configured');
        }

        if (decodedToken.aud !== expectedProjectId) {
          this.logger.error(`Token audience mismatch: expected ${expectedProjectId}, got ${decodedToken.aud}`);
          throw new UnauthorizedException('Firebase ID token audience mismatch');
        }

        return decodedToken;
      } catch (error) {
        if (error instanceof UnauthorizedException) {
          throw error;
        }
        this.logger.warn(`Firebase token verification fallback to Google Auth Library: ${error?.message}`);
      }
    }

    // 2. Fallback: Verify using google-auth-library in case client sent direct Google ID token.
    //
    // SECURITY: this path is only reachable when an explicit audience allow-list is
    // configured. Calling verifyIdToken() without `audience` makes google-auth-library
    // skip the `aud` claim check, so any Google-signed token minted for any unrelated
    // OAuth client would be accepted and its email trusted as the caller's identity.
    if (this.googleAudiences.length === 0) {
      throw new UnauthorizedException('Invalid, expired, or unverified Google/Firebase ID token');
    }

    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: this.googleAudiences,
      });
      const payload = ticket.getPayload();

      // Defence in depth: re-check the audience ourselves rather than relying solely
      // on the library, and require a Google-verified email before trusting it.
      if (payload && !this.googleAudiences.includes(payload.aud)) {
        this.logger.error(`Google token audience rejected: ${payload.aud}`);
        throw new UnauthorizedException('Google ID token audience mismatch');
      }

      if (payload && payload.email_verified === false) {
        throw new UnauthorizedException('Google account email is not verified');
      }

      if (payload && payload.email) {
        return {
          uid: payload.sub,
          email: payload.email,
          name: payload.name,
          picture: payload.picture,
          aud: payload.aud,
        } as any;
      }
    } catch (fallbackErr) {
      if (fallbackErr instanceof UnauthorizedException) {
        throw fallbackErr;
      }
      this.logger.error(`Google auth fallback verification failed: ${fallbackErr?.message}`);
    }

    throw new UnauthorizedException('Invalid, expired, or unverified Google/Firebase ID token');
  }
}
