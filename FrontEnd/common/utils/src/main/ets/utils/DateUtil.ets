export class DateUtil {
  static formatDate(date: Date, fmt: string = 'yyyy-MM-dd'): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return fmt.replace('yyyy', String(year)).replace('MM', month).replace('dd', day)
      .replace('HH', hours).replace('mm', minutes).replace('ss', seconds);
  }
  static parseISO(isoStr: string): Date { return new Date(isoStr); }
}
