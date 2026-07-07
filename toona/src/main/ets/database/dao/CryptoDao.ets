import { Dao, Insert, OnConflictStrategy, Query, Params, Room } from '@mlethe/room';
import { InboundGroupSessionEntity } from '../entities/InboundGroupSessionEntity';
import { OlmSessionEntity } from '../entities/OlmSessionEntity';
import { ToonaDatabase } from '../ToonaDatabase';
import { AppLogger } from '../../utils/AppLogger';

const logger = AppLogger.getLogger('CryptoDao');

/**
 * DAO for InboundGroupSession entities (Megolm sessions)
 */
@Dao({ database: ToonaDatabase, entity: InboundGroupSessionEntity })
export class InboundGroupSessionDao {
  @Insert({ onConflict: OnConflictStrategy.REPLACE })
  async insert(entity: InboundGroupSessionEntity): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: InboundGroupSessionEntity, isArray: false, sql: "SELECT * FROM inbound_group_sessions WHERE sessionId = :sessionId LIMIT 1" })
  async getBySessionId(@Params("sessionId") sessionId: string): Promise<InboundGroupSessionEntity | undefined> {
    return undefined;
  }

  @Query({ entity: InboundGroupSessionEntity, isArray: false, sql: "SELECT * FROM inbound_group_sessions WHERE room_id = :roomId AND megolm_session_id = :megolmSessionId LIMIT 1" })
  async getByRoomAndSession(@Params("roomId") roomId: string, @Params("megolmSessionId") megolmSessionId: string): Promise<InboundGroupSessionEntity | undefined> {
    return undefined;
  }

  @Query({ entity: InboundGroupSessionEntity, isArray: true, sql: "SELECT * FROM inbound_group_sessions" })
  async getAll(): Promise<InboundGroupSessionEntity[]> {
    return [];
  }

  @Query({ entity: InboundGroupSessionEntity, isArray: false, sql: "DELETE FROM inbound_group_sessions WHERE sessionId = :sessionId" })
  async deleteBySessionId(@Params("sessionId") sessionId: string): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: InboundGroupSessionEntity, isArray: false, sql: "DELETE FROM inbound_group_sessions" })
  async deleteAll(): Promise<number> {
    return Promise.resolve(0);
  }
}

/**
 * DAO for OlmSession entities
 */
@Dao({ database: ToonaDatabase, entity: OlmSessionEntity })
export class OlmSessionDao {
  @Insert({ onConflict: OnConflictStrategy.REPLACE })
  async insert(entity: OlmSessionEntity): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: OlmSessionEntity, isArray: false, sql: "SELECT * FROM olm_sessions WHERE sessionId = :sessionId LIMIT 1" })
  async getBySessionId(@Params("sessionId") sessionId: string): Promise<OlmSessionEntity | undefined> {
    return undefined;
  }

  @Query({ entity: OlmSessionEntity, isArray: false, sql: "SELECT * FROM olm_sessions WHERE device_key = :deviceKey LIMIT 1" })
  async getByDeviceKey(@Params("deviceKey") deviceKey: string): Promise<OlmSessionEntity | undefined> {
    return undefined;
  }

  @Query({ entity: OlmSessionEntity, isArray: true, sql: "SELECT * FROM olm_sessions" })
  async getAll(): Promise<OlmSessionEntity[]> {
    return [];
  }

  @Query({ entity: OlmSessionEntity, isArray: false, sql: "DELETE FROM olm_sessions WHERE sessionId = :sessionId" })
  async deleteBySessionId(@Params("sessionId") sessionId: string): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: OlmSessionEntity, isArray: false, sql: "DELETE FROM olm_sessions" })
  async deleteAll(): Promise<number> {
    return Promise.resolve(0);
  }
}

/**
 * CryptoDao provides a unified interface for E2EE crypto storage operations.
 * Uses Room ORM for database persistence.
 */
export class CryptoDao {
  private static instance: CryptoDao;
  private inboundGroupSessionDao: InboundGroupSessionDao | null = null;
  private olmSessionDao: OlmSessionDao | null = null;

  private constructor() {}

  static getInstance(): CryptoDao {
    if (!CryptoDao.instance) {
      CryptoDao.instance = new CryptoDao();
    }
    return CryptoDao.instance;
  }

  /**
   * Initialize the CryptoDao with Room ORM DAOs
   */
  init(): void {
    try {
      this.inboundGroupSessionDao = Room.getDao(InboundGroupSessionDao);
      this.olmSessionDao = Room.getDao(OlmSessionDao);
      logger.info('CryptoDao initialized with Room ORM');
    } catch (error) {
      logger.error('Failed to initialize CryptoDao with Room ORM:', error);
    }
  }

  /**
   * Check if DAOs are initialized
   */
  isInitialized(): boolean {
    return this.inboundGroupSessionDao !== null && this.olmSessionDao !== null;
  }

  // InboundGroupSession operations
  async saveInboundGroupSession(session: InboundGroupSessionEntity): Promise<void> {
    if (!this.inboundGroupSessionDao) {
      logger.error('InboundGroupSessionDao not initialized');
      return;
    }

    try {
      await this.inboundGroupSessionDao.insert(session);
      logger.debug(`Saved inbound session ${session.sessionId}`);
    } catch (error) {
      logger.error(`Failed to save inbound session ${session.sessionId}:`, error);
    }
  }

  async getInboundGroupSession(sessionId: string): Promise<InboundGroupSessionEntity | null> {
    if (!this.inboundGroupSessionDao) {
      logger.error('InboundGroupSessionDao not initialized');
      return null;
    }

    try {
      const result = await this.inboundGroupSessionDao.getBySessionId(sessionId);
      return result || null;
    } catch (error) {
      logger.error(`Failed to get inbound session ${sessionId}:`, error);
      return null;
    }
  }

  async getInboundGroupSessionByRoomAndSession(roomId: string, megolmSessionId: string): Promise<InboundGroupSessionEntity | null> {
    if (!this.inboundGroupSessionDao) {
      logger.error('InboundGroupSessionDao not initialized');
      return null;
    }

    try {
      const result = await this.inboundGroupSessionDao.getByRoomAndSession(roomId, megolmSessionId);
      return result || null;
    } catch (error) {
      logger.error(`Failed to get inbound session by room and session:`, error);
      return null;
    }
  }

  async getAllInboundGroupSessions(): Promise<InboundGroupSessionEntity[]> {
    if (!this.inboundGroupSessionDao) {
      logger.error('InboundGroupSessionDao not initialized');
      return [];
    }

    try {
      return await this.inboundGroupSessionDao.getAll();
    } catch (error) {
      logger.error('Failed to get all inbound sessions:', error);
      return [];
    }
  }

  async deleteInboundGroupSession(sessionId: string): Promise<void> {
    if (!this.inboundGroupSessionDao) {
      logger.error('InboundGroupSessionDao not initialized');
      return;
    }

    try {
      await this.inboundGroupSessionDao.deleteBySessionId(sessionId);
      logger.debug(`Deleted inbound session ${sessionId}`);
    } catch (error) {
      logger.error(`Failed to delete inbound session ${sessionId}:`, error);
    }
  }

  // OlmSession operations
  async saveOlmSession(session: OlmSessionEntity): Promise<void> {
    if (!this.olmSessionDao) {
      logger.error('OlmSessionDao not initialized');
      return;
    }

    try {
      await this.olmSessionDao.insert(session);
      logger.debug(`Saved Olm session ${session.sessionId}`);
    } catch (error) {
      logger.error(`Failed to save Olm session ${session.sessionId}:`, error);
    }
  }

  async getOlmSession(sessionId: string): Promise<OlmSessionEntity | null> {
    if (!this.olmSessionDao) {
      logger.error('OlmSessionDao not initialized');
      return null;
    }

    try {
      const result = await this.olmSessionDao.getBySessionId(sessionId);
      return result || null;
    } catch (error) {
      logger.error(`Failed to get Olm session ${sessionId}:`, error);
      return null;
    }
  }

  async getOlmSessionByDeviceKey(deviceKey: string): Promise<OlmSessionEntity | null> {
    if (!this.olmSessionDao) {
      logger.error('OlmSessionDao not initialized');
      return null;
    }

    try {
      const result = await this.olmSessionDao.getByDeviceKey(deviceKey);
      return result || null;
    } catch (error) {
      logger.error(`Failed to get Olm session by device key:`, error);
      return null;
    }
  }

  async getAllOlmSessions(): Promise<OlmSessionEntity[]> {
    if (!this.olmSessionDao) {
      logger.error('OlmSessionDao not initialized');
      return [];
    }

    try {
      return await this.olmSessionDao.getAll();
    } catch (error) {
      logger.error('Failed to get all Olm sessions:', error);
      return [];
    }
  }

  async deleteOlmSession(sessionId: string): Promise<void> {
    if (!this.olmSessionDao) {
      logger.error('OlmSessionDao not initialized');
      return;
    }

    try {
      await this.olmSessionDao.deleteBySessionId(sessionId);
      logger.debug(`Deleted Olm session ${sessionId}`);
    } catch (error) {
      logger.error(`Failed to delete Olm session ${sessionId}:`, error);
    }
  }
}
