/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREFERENCES_NAME: string = 'MobileIMSDKStore';

/**
 * Preference读写管理类。
 *
 * @author huawei
 */
export default class PreferenceManager {
  private preferences?: preferences.Preferences;
  private context?: common.UIAbilityContext;
  private static instance: PreferenceManager;

  private constructor(context?: common.UIAbilityContext) {
    this.context = context;
    if (context) {
      this.initPreference(PREFERENCES_NAME);
    }
  }

  public static getInstance(context?: common.UIAbilityContext): PreferenceManager {
    if (!PreferenceManager.instance) {
      if (!context) {
        throw new Error('Context must be provided for first initialization');
      }
      PreferenceManager.instance = new PreferenceManager(context);
    } else if (context && !PreferenceManager.instance.context) {
      // Update context if not set
      PreferenceManager.instance.context = context;
      PreferenceManager.instance.initPreference(PREFERENCES_NAME);
    }
    return PreferenceManager.instance;
  }

  async initPreference(storeName: string): Promise<void> {
    if (!this.context) {
      throw new Error('Context is not set');
    }
    return preferences.getPreferences(this.context, storeName)
      .then((preferences: preferences.Preferences) => {
        this.preferences = preferences;
      });
  }

  async setValue<T>(key: string, value: T): Promise<void> {
    if (this.preferences) {
      this.preferences.put(key, JSON.stringify(value)).then(() => {
        this.saveUserData();
      })
    } else {
      this.initPreference(PREFERENCES_NAME).then(() => {
        this.setValue<T>(key, value);
      });
    }
  }

  async getValue<T>(key: string): Promise<T | null> {
    if (this.preferences) {
      return this.preferences.get(key, '').then((res: preferences.ValueType) => {
        let value: T | null = null;
        if (res) {
          value = JSON.parse(res as string) as T;
        }
        return value;
      });
    } else {
      return this.initPreference(PREFERENCES_NAME).then(() => {
        return this.getValue<T>(key);
      });
    }
  }

  async hasValue(key: string): Promise<boolean> {
    if (this.preferences) {
      return this.preferences.has(key);
    } else {
      return this.initPreference(PREFERENCES_NAME).then(() => {
        return this.hasValue(key);
      });
    }
  }

  async deleteValue(key: string): Promise<void> {
    if (this.preferences) {
      this.preferences.delete(key).then(() => {
        this.saveUserData();
      });
    } else {
      this.initPreference(PREFERENCES_NAME).then(() => {
        this.deleteValue(key);
      });
    }
  }

  saveUserData() {
    this.preferences?.flush();
  }
}