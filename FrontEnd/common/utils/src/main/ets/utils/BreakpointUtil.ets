export class BreakpointUtil {
  static getBreakpoint(width: number): string {
    if (width < 600) { return 'sm'; }
    else if (width < 840) { return 'md'; }
    else { return 'lg'; }
  }
}
