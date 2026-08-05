import { Message } from '../models/DataModels';

export function formatTime(timestamp: number): string {
  const date: Date = new Date(timestamp);
  return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
}

export function getTimeGroupLabel(timestamp: number): string {
  const date: Date = new Date(timestamp);
  const today: Date = new Date();
  const yesterday: Date = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  if (date.toDateString() === today.toDateString()) {
    return '今天';
  } else if (date.toDateString() === yesterday.toDateString()) {
    return '昨天';
  } else {
    return date.toLocaleDateString('zh-CN', { month: 'long', day: 'numeric' });
  }
}

export function shouldShowTimeGroup(messages: Message[], index: number): boolean {
  if (index === 0) {
    return true;
  }
  const currentTime: number = messages[index].timestamp;
  const prevTime: number = messages[index - 1].timestamp;
  const currentDate: string = new Date(currentTime).toDateString();
  const prevDate: string = new Date(prevTime).toDateString();
  return currentDate !== prevDate;
}

export function getReplySenderName(sender: string): string {
  const colonIndex: number = sender.indexOf(':');
  return colonIndex > 0 ? sender.substring(1, colonIndex) : sender;
}
