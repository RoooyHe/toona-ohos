/**
 * Toast工具类 - 基于 wdkit 的 ToastUtils 封装
 *
 * 提供便捷的 Toast 方法，统一项目中 Toast 的使用风格。
 * 内部委托给 @wondertek/wdkitlib 的 ToastUtils 实现。
 */
import { ToastUtils as WdkitToast } from '@wondertek/wdkitlib';

/**
 * Toast 工具类
 *
 * 用法：
 * ```ts
 * ToastUtils.show('操作成功');
 * ToastUtils.short('网络错误');
 * ToastUtils.long('请稍候...');
 * ToastUtils.show('自定义颜色', 2000, '#ff0000', '#ffffff');
 * ```
 */
export class ToastUtils {
  /**
   * 显示 Toast
   *
   * @param message  内容文字
   * @param duration 时长（毫秒），默认 2000
   * @param backgroundColor 背景色（可选）
   * @param textColor       文字颜色（可选）
   */
  static show(message: string, duration?: number, backgroundColor?: ResourceColor, textColor?: ResourceColor): void {
    WdkitToast.showToast(message, duration, backgroundColor, textColor);
  }

  /**
   * 短 Toast（约 1s）
   */
  static short(message: string): void {
    WdkitToast.shortToast(message);
  }

  /**
   * 长 Toast（约 3s）
   */
  static long(message: string): void {
    WdkitToast.longToast(message);
  }

  /**
   * 带颜色的 Toast
   */
  static color(message: string, backgroundColor: ResourceColor, textColor?: ResourceColor): void {
    WdkitToast.colorToast(message, backgroundColor, textColor);
  }
}

export default ToastUtils;
