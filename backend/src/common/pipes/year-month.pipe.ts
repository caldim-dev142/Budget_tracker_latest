import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';

export const YEAR_MONTH_PATTERN = /^\d{4}-(0[1-9]|1[0-2])$/;

/** Validates a required `YYYY-MM` query parameter (month 01-12). */
@Injectable()
export class YearMonthPipe implements PipeTransform<unknown, string> {
  transform(value: unknown): string {
    if (typeof value !== 'string' || !YEAR_MONTH_PATTERN.test(value)) {
      throw new BadRequestException('yearMonth must be provided in YYYY-MM format (month 01-12).');
    }
    return value;
  }
}
