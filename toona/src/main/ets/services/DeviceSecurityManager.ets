import { securityDeviceManager, SecurityComponent, SecurityComponentData, SecurityComponentType } from '@kit.DeviceSecurityKit';
import { promptAction } from '@ohos.promptAction';

export class DeviceSecurityManager {
  private static instance: DeviceSecurityManager;

  static getInstance(): DeviceSecurityManager {
    if (!DeviceSecurityManager.instance) {
      DeviceSecurityManager.instance = new DeviceSecurityManager();
    }
    return DeviceSecurityManager.instance;
  }

  async isSecurityChipSupported(): Promise<boolean> {
    try {
      const result = securityDeviceManager.isSecurityDeviceSupported();
      console.info('Security chip support: %{public}s', result);
      return result;
    } catch (error) {
      console.error('Failed to check security chip: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async getSecurityComponent(type: SecurityComponentType): Promise<SecurityComponent | null> {
    try {
      const component = securityDeviceManager.getSecurityComponent(type);
      console.info('Got security component for type: %{public}d', type);
      return component;
    } catch (error) {
      console.error('Failed to get security component: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  async requestSecurityComponentData(type: SecurityComponentType): Promise<SecurityComponentData | null> {
    try {
      const component = await this.getSecurityComponent(type);
      if (!component) {
        return null;
      }
      
      const data = await component.getData();
      console.info('Security component data received');
      return data;
    } catch (error) {
      console.error('Failed to get security component data: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  async checkDeviceSecurityStatus(): Promise<Record<string, boolean>> {
    const status: Record<string, boolean> = {
      isSecure: false,
      hasSecurityChip: false,
      isEncrypted: false,
      isTrusted: false
    };

    try {
      status.hasSecurityChip = await this.isSecurityChipSupported();
      
      const teeComponent = await this.getSecurityComponent(SecurityComponentType.SECURITY_COMPONENT_TYPE_TEE);
      status.isSecure = teeComponent !== null;
      
      const huaweiKeystoreComponent = await this.getSecurityComponent(
        SecurityComponentType.SECURITY_COMPONENT_TYPE_HW_DEVICE_ID
      );
      status.isEncrypted = huaweiKeystoreComponent !== null;

      status.isTrusted = status.hasSecurityChip && status.isSecure;
    } catch (error) {
      console.error('Failed to check device security status: %{public}s', JSON.stringify(error));
    }

    return status;
  }

  analyzeMessageSecurity(message: string, senderId: string): { isSuspicious: boolean; riskLevel: string; warnings: string[] } {
    const warnings: string[] = [];
    let riskLevel = 'low';
    let isSuspicious = false;

    const urlRegex = /(https?:\/\/[^\s]+)|(www\.[^\s]+)|([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/gi;
    const urls = message.match(urlRegex);
    if (urls && urls.length > 0) {
      warnings.push('消息包含可疑链接');
      riskLevel = 'medium';
      isSuspicious = true;
    }

    const keywordPatterns = [
      { pattern: /转账|汇款|支付宝|微信红包|中奖|抽奖|退款/i, warning: '涉及金钱交易，请谨慎' },
      { pattern: /验证码|登录|密码.*确认|账户.*异常/i, warning: '可能涉及诈骗，请核实对方身份' },
      { pattern: /投资理财|高回报|稳赚|内幕消息/i, warning: '涉及投资诈骗，请谨慎' },
      { pattern: /点击链接|扫描二维码|领取礼品/i, warning: '可能为钓鱼信息' },
      { pattern: /紧急|立刻|马上|过期|冻结/i, warning: '可能为恐吓诈骗信息' }
    ];

    for (const item of keywordPatterns) {
      if (item.pattern.test(message)) {
        warnings.push(item.warning);
        isSuspicious = true;
        if (riskLevel !== 'high') {
          riskLevel = 'high';
        }
      }
    }

    const phoneRegex = /1[3-9]\d{9}/g;
    const phones = message.match(phoneRegex);
    if (phones && phones.length > 0) {
      warnings.push('消息包含电话号码');
      isSuspicious = true;
      if (riskLevel !== 'high') {
        riskLevel = 'medium';
      }
    }

    const idCardRegex = /\d{17}[\dXx]/g;
    if (idCardRegex.test(message)) {
      warnings.push('消息可能包含个人信息');
      isSuspicious = true;
      riskLevel = 'high';
    }

    return {
      isSuspicious,
      riskLevel,
      warnings
    };
  }

  showSecurityWarning(title: string, message: string, details: string[]): void {
    const fullMessage = details.length > 0 
      ? `${message}\n\n风险提示:\n${details.map(d => '• ' + d).join('\n')}`
      : message;
    
    promptAction.showToast({
      message: `${title}: ${fullMessage.substring(0, 100)}...`,
      duration: 5000
    });
  }
}

export enum SecurityComponentType {
  SECURITY_COMPONENT_TYPE_TEE = 1,
  SECURITY_COMPONENT_TYPE_HW_DEVICE_ID = 2,
  SECURITY_COMPONENT_TYPE_DEVICE_ID = 3,
  SECURITY_COMPONENT_TYPE_SPCI = 4,
  SECURITY_COMPONENT_TYPE_COTA = 5
}