import { preferences } from '@kit.ArkData';

class PreferencesUtil {
  private pref: preferences.Preferences | null = null;

  async init(context: Context): Promise<void> {
    this.pref = await preferences.getPreferences(context, 'mes_prefs');
  }

  set(key: string, value: string): void {
    this.pref?.put(key, value);
    this.pref?.flush();
  }

  get(key: string): string {
    return (this.pref?.get(key, '') as string) || '';
  }

  delete(key: string): void {
    this.pref?.delete(key);
    this.pref?.flush();
  }
}

export const preferencesUtil = new PreferencesUtil();
export { PreferencesUtil };
