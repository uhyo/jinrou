/**
 * Group of T's optionally grouped by a label.
 */
export type LabeledGroup<T, L> = Array<GroupOrItem<T, L>>;

/**
 * a group or an item.
 * An item is T and a label of groups is L.
 */
export type GroupOrItem<T, L> =
  | {
      type: 'group';
      label: L;
      items: Array<GroupOrItem<T, L>>;
    }
  | {
      type: 'item';
      value: T;
    };
