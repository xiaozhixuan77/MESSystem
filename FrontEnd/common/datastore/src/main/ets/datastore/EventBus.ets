import { emitter } from '@kit.BasicServicesKit';
export const LOGIN_EXPIRED_EVENT: emitter.InnerEvent = { eventId: 10001 };
export const LOGIN_SUCCESS_EVENT: emitter.InnerEvent = { eventId: 10002 };
export const WORKORDER_CHANGED_EVENT: emitter.InnerEvent = { eventId: 10003 };
export const PRODUCTION_CHANGED_EVENT: emitter.InnerEvent = { eventId: 10004 };