export class FormatUtil {
  static formatQty(qty: number): string {
    if (qty >= 10000) {
      return `${(qty / 10000).toFixed(1)}万`;
    }
    return String(qty);
  }

  static formatPercent(rate: number): string {
    return `${(rate * 100).toFixed(1)}%`;
  }

  static formatDuration(hours: number): string {
    if (hours < 1) {
      return `${Math.round(hours * 60)}分钟`;
    }
    return `${hours.toFixed(1)}小时`;
  }
}
