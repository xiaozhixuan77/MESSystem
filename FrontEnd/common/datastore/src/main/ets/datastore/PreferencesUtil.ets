import { preferences } from '@kit.ArkData';

class PreferencesUtil {
  private pref: preferences.Preferences | null = null;

  async init(context: Context): Promise<void> {
    this.pref = await preferences.getPreferences(context, 'mes_prefs');
  }

  async set(key: string, value: string): Promise<void> {
    await this.pref?.put(key, value);
    await this.pref?.flush();
  }

  async get(key: string): Promise<string> {
    const value = await this.pref?.get(key, '');
    return (value as string) || '';
  }

  async delete(key: string): Promise<void> {
    await this.pref?.delete(key);
    await this.pref?.flush();
  }
}

export const preferencesUtil = new PreferencesUtil();
export { PreferencesUtil };
