import { Injectable, OnModuleInit, UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth, DecodedIdToken } from 'firebase-admin/auth';
import { OAuth2Client } from 'google-auth-library';

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private readonly googleClient = new OAuth2Client();

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
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
        const expectedProjectId = this.config.get<string>('FIREBASE_PROJECT_ID', 'budget-tracker-d034f');

        if (expectedProjectId && decodedToken.aud !== expectedProjectId) {
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

    // 2. Fallback: Verify using google-auth-library in case client sent direct Google ID token
    try {
      const ticket = await this.googleClient.verifyIdToken({ idToken });
      const payload = ticket.getPayload();
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
      this.logger.error(`Google auth fallback verification failed: ${fallbackErr?.message}`);
    }

    throw new UnauthorizedException('Invalid, expired, or unverified Google/Firebase ID token');
  }
}
