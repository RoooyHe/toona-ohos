import { PropertyConverter } from '@mlethe/room';
import { AppLogger } from '../../utils/AppLogger';

export class ContentConverter extends PropertyConverter<Object> {
  private static logger = AppLogger.getLogger(ContentConverter);

  convertToDatabaseValue(entityProperty: Object): string {
    try {
      return JSON.stringify(entityProperty);
    } catch (error) {
      ContentConverter.logger.error('ContentConverter.convertToDatabaseValue failed:', error);
      return '{}';
    }
  }

  convertToEntityProperty(databaseValue: string): Object {
    if (!databaseValue) {
      return new Object();
    }
    try {
      return JSON.parse(databaseValue);
    } catch (error) {
      ContentConverter.logger.error('ContentConverter.convertToEntityProperty failed:', error);
      return new Object();
    }
  }
}
