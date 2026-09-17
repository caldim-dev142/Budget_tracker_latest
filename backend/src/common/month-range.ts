/**
 * Half-open month window [first instant of month, first instant of next month) in the server's
 * local time zone (same zone semantics as before; only the old 23:59:59.000 upper bound, which
 * dropped the final second of every month, is removed).
 */
export function monthRange(yearMonth: string): { from: Date; to: Date } {
  const [year, month] = yearMonth.split('-').map(Number);
  return { from: new Date(year, month - 1, 1), to: new Date(year, month, 1) };
}
