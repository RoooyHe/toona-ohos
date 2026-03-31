import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';

export interface ThemeColors {
  bg: string;
  text: string;
  textSecondary: string;
  inputBg: string;
  primary: string;
  divider: string;
  surface: string;
  tabBg: string;
}

export class ThemeManager {
  private static instance: ThemeManager;
  private isDarkMode: boolean = false;

  private constructor() {
    const colorMode = AppStorage.get<number>('colorMode');
    this.isDarkMode = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  setDarkMode(isDark: boolean): void {
    this.isDarkMode = isDark;
    const newMode = isDark ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    AppStorage.setOrCreate('colorMode', newMode);
  }

  getIsDarkMode(): boolean {
    const colorMode = AppStorage.get<number>('colorMode');
    return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  getColors(): ThemeColors {
    if (this.isDarkMode) {
      return {
        bg: '#1a1a1a',
        text: '#ffffff',
        textSecondary: '#999999',
        inputBg: '#2a2a2a',
        primary: '#10a37f',
        divider: '#3a3a3a',
        surface: '#2a2a2a',
        tabBg: '#2a2a2a'
      };
    }
    return {
      bg: '#ffffff',
      text: '#333333',
      textSecondary: '#999999',
      inputBg: '#f5f5f5',
      primary: '#10a37f',
      divider: '#f0f0f0',
      surface: '#ffffff',
      tabBg: '#f0f0f0'
    };
  }

  toggleDarkMode(): void {
    this.setDarkMode(!this.isDarkMode);
  }
}

export function getThemeColors(): ThemeColors {
  return ThemeManager.getInstance().getColors();
}

export function getIsDarkMode(): boolean {
  return ThemeManager.getInstance().getIsDarkMode();
}

export function toggleDarkMode(): void {
  ThemeManager.getInstance().toggleDarkMode();
}
