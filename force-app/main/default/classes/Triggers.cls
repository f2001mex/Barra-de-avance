/**
 * @description トリガー共通ハンドル定義。
 * @version 1.0
 */
public with sharing class Triggers {
	/**
	 * @description Enum representing each of before/after CRUD events on SObjects
	 */
	public enum Evt {
		afterDelete,
		afterInsert,
		afterUndelete,
		afterUpdate,
		beforeDelete,
		beforeInsert,
		beforeUpdate
	}

	/**
	 * @description Simplistic handler to implement on any of the event. It doesn't requires or enforces any patter except the
	 * method name to be "handle()", a developer is free to use any Trigger context variable or reuse any other
	 * apex class here.
	 */
	public interface Handler {
		void handle();
	}

	// Internal mapping of handlers
	Map<String, List<Handler>> eventHandlerMapping = new Map<String, List<Handler>>();

	/**
	 * @description Core API to bind handlers with events
	 *
	 * @param event トリガーイベント
	 * @param eh 処理ハンドラクラス
	 *
	 * @return ハンドル自身戻す
	 */
	public Triggers bind(Evt event, Handler eh) {
		List<Handler> handlers = eventHandlerMapping.get(event.name());
		if (handlers == null) {
			handlers = new List<Handler>();
			eventHandlerMapping.put(event.name(), handlers);
		}
		handlers.add(eh);
		return this;
	}

	/**
	 * @description Invokes correct handlers as per the context of trigger and available registered handlers
	 */
	public void manage() {
		Evt ev = null;
		if (Trigger.isInsert && Trigger.isBefore) {
			ev = Evt.beforeInsert;
		} else if (Trigger.isInsert && Trigger.isAfter) {
			ev = Evt.afterInsert;
		} else if (Trigger.isUpdate && Trigger.isBefore) {
			ev = Evt.beforeUpdate;
		} else if (Trigger.isUpdate && Trigger.isAfter) {
			ev = Evt.afterUpdate;
		} else if (Trigger.isDelete && Trigger.isBefore) {
			ev = Evt.beforeDelete;
		} else if (Trigger.isDelete && Trigger.isAfter) {
			ev = Evt.afterDelete;
		} else if (Trigger.isUndelete) {
			ev = Evt.afterUndelete;
		}
		List<Handler> handlers = eventHandlerMapping.get(ev.name());
		if (handlers != null && !handlers.isEmpty()) {
			for (Handler h : handlers) {
				h.handle();
			}
		}
	}
}