import { Dao, Insert, OnConflictStrategy, Query, Params, Room } from '@mlethe/room';
import { DeviceKeysEntity } from '../entities/DeviceKeysEntity';
import { ToonaDatabase } from '../ToonaDatabase';
import { AppLogger } from '../../utils/AppLogger';
import { VerificationState } from '../../crypto/types/CryptoTypes';

const logger = AppLogger.getLogger('DeviceKeysDao');

/**
 * DAO for DeviceKeysEntity - stores device identity keys and trust state
 */
@Dao({ database: ToonaDatabase, entity: DeviceKeysEntity })
export class DeviceKeysDao {
  @Insert({ onConflict: OnConflictStrategy.REPLACE })
  async insert(entity: DeviceKeysEntity): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: DeviceKeysEntity, isArray: false, sql: "SELECT * FROM device_keys WHERE user_id = :userId AND device_id = :deviceId LIMIT 1" })
  async getByUserAndDevice(@Params("userId") userId: string, @Params("deviceId") deviceId: string): Promise<DeviceKeysEntity | undefined> {
    return undefined;
  }

  @Query({ entity: DeviceKeysEntity, isArray: true, sql: "SELECT * FROM device_keys WHERE user_id = :userId" })
  async getByUserId(@Params("userId") userId: string): Promise<DeviceKeysEntity[]> {
    return [];
  }

  @Query({ entity: DeviceKeysEntity, isArray: true, sql: "SELECT * FROM device_keys" })
  async getAll(): Promise<DeviceKeysEntity[]> {
    return [];
  }

  @Query({ entity: DeviceKeysEntity, isArray: false, sql: "UPDATE device_keys SET trust_level = :trustLevel, verified_at = :verifiedAt, verified_by = :verifiedBy WHERE user_id = :userId AND device_id = :deviceId" })
  async updateTrustLevel(@Params("userId") userId: string, @Params("deviceId") deviceId: string, @Params("trustLevel") trustLevel: string, @Params("verifiedAt") verifiedAt: number, @Params("verifiedBy") verifiedBy: string): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: DeviceKeysEntity, isArray: false, sql: "DELETE FROM device_keys WHERE user_id = :userId" })
  async deleteByUserId(@Params("userId") userId: string): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: DeviceKeysEntity, isArray: false, sql: "DELETE FROM device_keys" })
  async deleteAll(): Promise<number> {
    return Promise.resolve(0);
  }
}

/**
 * DeviceKeysDao provides a unified interface for device key storage operations.
 */
export class DeviceKeysStorage {
  private static instance: DeviceKeysStorage;
  private deviceKeysDao: DeviceKeysDao | null = null;

  private constructor() {}

  static getInstance(): DeviceKeysStorage {
    if (!DeviceKeysStorage.instance) {
      DeviceKeysStorage.instance = new DeviceKeysStorage();
    }
    return DeviceKeysStorage.instance;
  }

  /**
   * Initialize with Room ORM DAO
   */
  init(): void {
    try {
      this.deviceKeysDao = Room.getDao(DeviceKeysDao);
      logger.info('DeviceKeysStorage initialized with Room ORM');
    } catch (error) {
      logger.error('Failed to initialize DeviceKeysStorage:', error);
    }
  }

  /**
   * Save device keys
   */
  async saveDeviceKeys(userId: string, deviceId: string, ed25519Key: string, curve25519Key: string, algorithms: string[], signatures: Record<string, Record<string, string>>): Promise<void> {
    if (!this.deviceKeysDao) {
      logger.error('DeviceKeysDao not initialized');
      return;
    }

    try {
      const entity = new DeviceKeysEntity();
      entity.user_id = userId;
      entity.device_id = deviceId;
      entity.ed25519_key = ed25519Key;
      entity.curve25519_key = curve25519Key;
      entity.algorithms = JSON.stringify(algorithms);
      entity.signatures = JSON.stringify(signatures);
      entity.trust_level = VerificationState.UNVERIFIED;
      entity.verified_at = 0;
      entity.verified_by = '';
      entity.created_at = Date.now();

      await this.deviceKeysDao.insert(entity);
      logger.info(`Saved device keys for ${userId}:${deviceId}`);
    } catch (error) {
      logger.error(`Failed to save device keys:`, error);
    }
  }

  /**
   * Get device keys for a specific user and device
   */
  async getDeviceKeys(userId: string, deviceId?: string): Promise<DeviceKeysEntity | null> {
    if (!this.deviceKeysDao) {
      logger.error('DeviceKeysDao not initialized');
      return null;
    }

    try {
      if (deviceId) {
        const result = await this.deviceKeysDao.getByUserAndDevice(userId, deviceId);
        return result || null;
      }
      const results = await this.deviceKeysDao.getByUserId(userId);
      return results.length > 0 ? results[0] : null;
    } catch (error) {
      logger.error(`Failed to get device keys for ${userId}:`, error);
      return null;
    }
  }

  /**
   * Get all devices for a user
   */
  async getAllDevicesForUser(userId: string): Promise<DeviceKeysEntity[]> {
    if (!this.deviceKeysDao) {
      logger.error('DeviceKeysDao not initialized');
      return [];
    }

    try {
      return await this.deviceKeysDao.getByUserId(userId);
    } catch (error) {
      logger.error(`Failed to get devices for ${userId}:`, error);
      return [];
    }
  }

  /**
   * Get trust level for a device
   */
  async getTrustLevel(userId: string, deviceId: string): Promise<VerificationState> {
    const keys = await this.getDeviceKeys(userId, deviceId);
    if (!keys) {
      return VerificationState.UNVERIFIED;
    }
    return keys.trust_level as VerificationState || VerificationState.UNVERIFIED;
  }

  /**
   * Update trust level for a device
   */
  async setTrustLevel(userId: string, deviceId: string, trustLevel: VerificationState, verifiedBy?: string): Promise<void> {
    if (!this.deviceKeysDao) {
      logger.error('DeviceKeysDao not initialized');
      return;
    }

    try {
      const verifiedAt = trustLevel === VerificationState.VERIFIED ? Date.now() : 0;
      const verifier = verifiedBy || '';
      await this.deviceKeysDao.updateTrustLevel(userId, deviceId, trustLevel, verifiedAt, verifier);
      logger.info(`Updated trust level for ${userId}:${deviceId} to ${trustLevel}`);
    } catch (error) {
      logger.error(`Failed to update trust level:`, error);
    }
  }

  /**
   * Delete device keys for a user
   */
  async deleteDeviceKeys(userId: string): Promise<void> {
    if (!this.deviceKeysDao) {
      logger.error('DeviceKeysDao not initialized');
      return;
    }

    try {
      await this.deviceKeysDao.deleteByUserId(userId);
      logger.info(`Deleted device keys for ${userId}`);
    } catch (error) {
      logger.error(`Failed to delete device keys for ${userId}:`, error);
    }
  }
}
