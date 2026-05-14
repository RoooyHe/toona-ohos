import { PropertyConverter } from '@mlethe/room';
import { TagInfo } from '../../models/DataModels';
import { AppLogger } from '../../utils/AppLogger';

export class TagsConverter extends PropertyConverter<Object> {
  private static logger = AppLogger.getLogger(TagsConverter);

  convertToDatabaseValue(entityProperty: Object): string {
    try {
      return JSON.stringify(entityProperty);
    } catch (error) {
      TagsConverter.logger.error('TagsConverter.convertToDatabaseValue failed:', error);
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
      TagsConverter.logger.error('TagsConverter.convertToEntityProperty failed:', error);
      return new Object();
    }
}

}
