import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';

export type ColorModeType = 'light' | 'dark' | 'system';

export interface ThemeColors {
  bg: string;
  text: string;
  textSecondary: string;
  inputBg: string;
  primary: string;
  divider: string;
  surface: string;
  tabBg: string;
  error: string;
}

export class ThemeManager {
  private static instance: ThemeManager;
  private colorModeType: ColorModeType = 'light';
  private systemColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  private constructor() {
    this.initializeColorMode();
  }

  private initializeColorMode(): void {
    const savedMode = AppStorage.get<ColorModeType>('colorModeType');
    if (savedMode) {
      this.colorModeType = savedMode;
    } else {
      this.colorModeType = 'light';
      AppStorage.setOrCreate('colorModeType', 'light');
    }
    
    // Listen for system color mode changes
    const systemColorMode = AppStorage.get<number>('systemColorMode');
    if (systemColorMode !== undefined) {
      this.systemColorMode = systemColorMode;
    }
  }

  private updateFromSystemColorMode(): void {
    const systemColorMode = AppStorage.get<number>('systemColorMode');
    if (systemColorMode !== undefined) {
      this.systemColorMode = systemColorMode;
    }
  }

  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  setColorMode(mode: ColorModeType): void {
    this.colorModeType = mode;
    AppStorage.setOrCreate('colorModeType', mode);
    
    if (mode === 'system') {
      this.updateFromSystemColorMode();
    }
  }

  getColorModeType(): ColorModeType {
    return this.colorModeType;
  }

  isDarkMode(): boolean {
    this.updateFromSystemColorMode();
    if (this.colorModeType === 'dark') {
      return true;
    } else if (this.colorModeType === 'light') {
      return false;
    } else {
      // Follow system
      return this.systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
  }

  getColors(): ThemeColors {
    const dark = this.isDarkMode();
    if (dark) {
      return {
        bg: '#1a1a1a',
        text: '#ffffff',
        textSecondary: '#999999',
        inputBg: '#2a2a2a',
        primary: '#10a37f',
        divider: '#3a3a3a',
        surface: '#2a2a2a',
        tabBg: '#2a2a2a',
        error: '#e53935'
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
      tabBg: '#f0f0f0',
      error: '#e53935'
    };
  }
}

export function getThemeColors(): ThemeColors {
  return ThemeManager.getInstance().getColors();
}

export function getIsDarkMode(): boolean {
  return ThemeManager.getInstance().isDarkMode();
}

export function getColorModeType(): ColorModeType {
  return ThemeManager.getInstance().getColorModeType();
}

export function setColorMode(mode: ColorModeType): void {
  ThemeManager.getInstance().setColorMode(mode);
}
