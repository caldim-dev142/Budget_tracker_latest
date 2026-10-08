import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: Transporter | null = null;
  private readonly fromEmail: string;
  private readonly fromName: string;

  constructor(private readonly config: ConfigService) {
    const host = this.config.get<string>('SMTP_HOST');
    const port = parseInt(this.config.get<string>('SMTP_PORT') || '587', 10);
    const secure = this.config.get<string>('SMTP_SECURE') === 'true' || port === 465;
    const user = this.config.get<string>('SMTP_USER');
    const pass = this.config.get<string>('SMTP_PASSWORD');

    this.fromEmail = this.config.get<string>('SMTP_FROM') || user || 'noreply@caldimproducts.com';
    this.fromName = this.config.get<string>('SMTP_FROM_NAME') || 'CalBudget';

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: {
          user,
          pass,
        },
      });
      this.logger.log(`SMTP EmailService initialized with host: ${host}:${port}`);
    } else if (host) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
      });
      this.logger.log(`SMTP EmailService initialized without auth for host: ${host}:${port}`);
    } else {
      this.logger.warn('SMTP_HOST is not configured. Outgoing emails will be mocked in non-production environments.');
    }
  }

  async sendOtpEmail(toEmail: string, otp: string): Promise<void> {
    const subject = 'Your CalBudget verification code';
    const textContent = `Your CalBudget verification code is:\n\n${otp}\n\nThis code expires in 5 minutes.\n\nIf you did not request this code, you can ignore this email.`;
    const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Your CalBudget verification code</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f4f7f6; margin: 0; padding: 24px;">
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr>
      <td align="center">
        <table width="100%" style="max-width: 500px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); padding: 32px; border: 1px solid #eaeaea;">
          <tr>
            <td align="center" style="padding-bottom: 24px;">
              <h1 style="color: #1a73e8; margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px;">CalBudget</h1>
              <p style="color: #666666; margin: 6px 0 0 0; font-size: 14px;">Smart Household & Personal Budgeting</p>
            </td>
          </tr>
          <tr>
            <td style="color: #333333; font-size: 16px; line-height: 24px;">
              <p style="margin: 0 0 16px 0;">Hello,</p>
              <p style="margin: 0 0 24px 0;">Use the following 6-digit verification code to sign in to your CalBudget account:</p>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding: 16px 0 24px 0;">
              <div style="background-color: #f0f4ff; border: 2px dashed #3b82f6; border-radius: 12px; padding: 18px 32px; display: inline-block;">
                <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 800; color: #1e40af; letter-spacing: 8px;">${otp}</span>
              </div>
            </td>
          </tr>
          <tr>
            <td style="color: #555555; font-size: 14px; line-height: 22px;">
              <p style="margin: 0 0 12px 0;">⏱️ <strong>This code expires in 5 minutes.</strong></p>
              <p style="margin: 0 0 24px 0; color: #777777;">If you did not request this verification code, please disregard this email. Your account remains secure.</p>
            </td>
          </tr>
          <tr>
            <td style="border-top: 1px solid #eeeeee; padding-top: 20px; color: #999999; font-size: 12px; text-align: center;">
              &copy; ${new Date().getFullYear()} Caldim Products. All rights reserved.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

    if (!this.transporter) {
      if (this.config.get('NODE_ENV') === 'production') {
        throw new Error('SMTP service is not configured in production. Cannot send OTP email.');
      }
      this.logger.warn(`[DEV/TEST MOCK EMAIL] To: ${toEmail} | Subject: ${subject} | (OTP masked for security)`);
      return;
    }

    try {
      await this.transporter.sendMail({
        from: `"${this.fromName}" <${this.fromEmail}>`,
        to: toEmail,
        subject,
        text: textContent,
        html: htmlContent,
      });
      this.logger.log(`OTP email sent successfully to: ${toEmail}`);
    } catch (err: any) {
      this.logger.error(`Failed to send OTP email to ${toEmail}: ${err?.message}`, err?.stack);
      throw new Error(`Email delivery failed. Please check your email configuration or try again later.`);
    }
  }

  async verifySmtpConnection(): Promise<{ success: boolean; message: string }> {
    if (!this.transporter) {
      return { success: false, message: 'SMTP transporter not configured (missing SMTP_HOST).' };
    }
    try {
      await this.transporter.verify();
      return { success: true, message: 'SMTP server connection verified successfully.' };
    } catch (err: any) {
      return { success: false, message: err?.message || 'Failed to verify SMTP connection.' };
    }
  }
}
