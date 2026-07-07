import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';

export type ColorModeType = 'light' | 'dark' | 'system';

export interface ThemeColors {
  // Surfaces
  bg: string;
  bgSoft: string;
  surface: string;
  surfaceNight: string;
  surfaceNightSoft: string;

  // Text
  text: string;
  textSecondary: string;
  textMute: string;
  textMute2: string;
  textFaint: string;

  // Brand
  primary: string;
  primaryDeep: string;
  primarySoft: string;
  onPrimary: string;

  // Borders
  divider: string;
  dividerStrong: string;
  dividerCool: string;

  // Semantic
  error: string;
  success: string;
  warning: string;

  // Form
  inputBg: string;

  // Tab
  tabBg: string;
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
        bgSoft: '#222222',
        surface: '#2a2a2a',
        surfaceNight: '#1c1c1c',
        surfaceNightSoft: '#202020',
        text: '#ffffff',
        textSecondary: '#cccccc',
        textMute: '#999999',
        textMute2: '#777777',
        textFaint: '#555555',
        primary: '#3ecf8e',
        primaryDeep: '#24b47e',
        primarySoft: '#4ade80',
        onPrimary: '#171717',
        divider: '#3a3a3a',
        dividerStrong: '#555555',
        dividerCool: '#333333',
        error: '#e53935',
        success: '#4CAF50',
        warning: '#FF9800',
        inputBg: '#2a2a2a',
        tabBg: '#2a2a2a'
      };
    }
    return {
      bg: '#ffffff',
      bgSoft: '#fafafa',
      surface: '#ffffff',
      surfaceNight: '#1c1c1c',
      surfaceNightSoft: '#202020',
      text: '#171717',
      textSecondary: '#212121',
      textMute: '#707070',
      textMute2: '#9a9a9a',
      textFaint: '#b2b2b2',
      primary: '#3ecf8e',
      primaryDeep: '#24b47e',
      primarySoft: '#4ade80',
      onPrimary: '#171717',
      divider: '#dfdfdf',
      dividerStrong: '#c7c7c7',
      dividerCool: '#ededed',
      error: '#e53935',
      success: '#4CAF50',
      warning: '#FF9800',
      inputBg: '#fafafa',
      tabBg: '#f0f0f0'
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
