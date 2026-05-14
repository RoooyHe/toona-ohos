/*
 * Copyright (c) 2024 Toona
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { LogManager, Level, Logger } from '@pie/log4a';

const LOG_PREFIX = '[Toona]';

// 构建模式开关 — debug=true 输出 DEBUG+, release 只输出 INFO+
const IS_DEBUG_BUILD: boolean = true;
const MIN_LEVEL: Level = IS_DEBUG_BUILD ? Level.ALL : Level.INFO;

class AppLoggerProxy {
  private logger: Logger;

  constructor(logger: Logger) {
    this.logger = logger;
    this.logger.setLevel(MIN_LEVEL);
  }

  /**
   * INFO 级别日志
   * 支持 console.log 风格的多参数拼接
   */
  info(msg: string, ...args: object[]): void {
    this.logger.info(this.buildMsg(msg, args));
  }

  /**
   * ERROR 级别日志
   */
  error(msg: string, ...args: object[]): void {
    this.logger.error(this.buildMsg(msg, args));
  }

  /**
   * WARN 级别日志
   */
  warn(msg: string, ...args: object[]): void {
    this.logger.warn(this.buildMsg(msg, args));
  }

  /**
   * DEBUG 级别日志（仅在 debug 构建生效）
   */
  debug(msg: string, ...args: object[]): void {
    this.logger.debug(this.buildMsg(msg, args));
  }

  /**
   * TRACE 级别日志
   */
  trace(msg: string, ...args: object[]): void {
    this.logger.trace(this.buildMsg(msg, args));
  }

  /**
   * FATAL 级别日志
   */
  fatal(msg: string, ...args: object[]): void {
    this.logger.fatal(this.buildMsg(msg, args));
  }

  private buildMsg(msg: string, args: object[]): string {
    if (args.length === 0) {
      return `${LOG_PREFIX} ${msg}`;
    }
    const parts = [msg, ...args.map(a => {
      if (typeof a === 'object') {
        try {
          return JSON.stringify(a);
        } catch {
          return String(a);
        }
      }
      return String(a);
    })];
    return `${LOG_PREFIX} ${parts.join(' ')}`;
  }
}

/**
 * AppLogger - 应用日志工具类
 *
 * 基于 @pie/log4a 封装：
 * - 自动添加 [Toona] 前缀
 * - 类名自动作为 tag（通过 LogManager.getLogger 实现）
 * - Debug/Release 级别控制
 *
 * 使用方式（替换 console.* 调用）：
 *
 *   // 文件顶部
 *   import { AppLogger } from '../utils/AppLogger';
 *   const logger = AppLogger.getLogger(ClassName);
 *
 *   // 使用（参数风格兼容 console）
 *   logger.info('message');
 *   logger.error('Failed to save:', error);
 *   logger.warn('Something unusual:', detail);
 */
export class AppLogger {
  private static loggerMap: Map<string, AppLoggerProxy> = new Map();

  /**
   * 获取Logger实例
   * @param context 类对象或字符串 tag 名
   * @returns AppLoggerProxy
   */
  static getLogger<T extends Object>(context: T | string): AppLoggerProxy {
    let key: string;
    if (typeof context === 'string') {
      key = context;
    } else if (context && context.constructor) {
      key = context.constructor.name;
    } else {
      key = 'Anonymous';
    }

    const existing = AppLogger.loggerMap.get(key);
    if (existing) {
      return existing;
    }

    const rawLogger = LogManager.getLogger(context);
    const proxy = new AppLoggerProxy(rawLogger);
    AppLogger.loggerMap.set(key, proxy);
    return proxy;
  }
}
