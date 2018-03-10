import * as React from 'react';

import { LabeledGroup, GroupOrItem } from '../defs/labeled-group';

import { ReactCtor } from './react-type';

/**
 * Iterate items of labeled group.
 */
export function* iterateLabeledGroup<T, L>(
  items: LabeledGroup<T, L>,
): IterableIterator<T> {
  for (const item of items) {
    if (item.type === 'group') {
      yield* iterateLabeledGroup(item.items);
    } else {
      yield item.value;
    }
  }
}
/**
 * Find given item for labeled group.
 */
export function findLabeledGroupItem<T, L>(
  items: LabeledGroup<T, L>,
  predicate: (item: T) => boolean,
): T | undefined {
  for (const item of iterateLabeledGroup(items)) {
    if (predicate(item)) {
      return item;
    }
  }
  return undefined;
}

export interface IPropSelectLabeledGroup<T, L> {
  /**
   * Items of this select.
   */
  items: LabeledGroup<T, L>;
  /**
   * Current value of selection.
   */
  value: string;
  getGroupLabel: (
    label: L,
  ) => {
    key: string;
    label: string;
  };
  getOptionKey: (value: T) => string;
  makeOption: (value: T) => React.ReactElement<HTMLOptionElement>;
  onChange?: (value: T) => void;
}

/**
 * Genelate a selection of given LabeledGroup.
 */
export class SelectLabeledGroup<T, L> extends React.PureComponent<
  IPropSelectLabeledGroup<T, L>,
  {}
> {
  public render() {
    const {
      items,
      value,
      getGroupLabel,
      getOptionKey,
      makeOption,
      onChange,
    } = this.props;

    const itemMap = new Map();
    const tree = genTree({
      items,
      getGroupLabel,
      getOptionKey,
      itemMap,
    });

    const TOT: ReactCtor<IPropTreeOption<T>, {}> = TreeOption;

    const changeHandler =
      onChange != null
        ? ({ currentTarget }: React.SyntheticEvent<HTMLSelectElement>) => {
            const { value } = currentTarget;
            const v = itemMap.get(value);
            if (v != null) {
              onChange(v);
            }
          }
        : undefined;

    return (
      <select value={value} onChange={changeHandler}>
        {tree.map(item => (
          <TOT key={item.key} item={item} makeOption={makeOption} />
        ))}
      </select>
    );
  }
}

interface IGentreeInput<T, L> {
  items: LabeledGroup<T, L>;
  getGroupLabel: (
    label: L,
  ) => {
    key: string;
    label: string;
  };
  getOptionKey: (value: T) => string;
  /**
   * Map from key to item.
   */
  itemMap: Map<string, T>;
}

function genTree<T, L>({
  items,
  getGroupLabel,
  getOptionKey,
  itemMap,
}: IGentreeInput<T, L>): Array<IOptionTree<T>> {
  const result: Array<IOptionTree<T>> = [];
  for (const item of items) {
    if (item.type === 'group') {
      const { key, label } = getGroupLabel(item.label);
      result.push({
        type: 'group',
        key: `group-${key}`,
        label,
        items: genTree({
          items: item.items,
          getGroupLabel,
          getOptionKey,
          itemMap,
        }),
      });
    } else {
      const { value } = item;
      const key = getOptionKey(value);
      itemMap.set(key, value);
      result.push({
        type: 'option',
        key: `option-${key}`,
        value,
      });
    }
  }
  return result;
}

interface IOptionTreeOption<T> {
  type: 'option';
  key: string;
  value: T;
}
interface IOptionTreeOptgroup<T> {
  type: 'group';
  key: string;
  label: string;
  items: Array<IOptionTree<T>>;
}
type IOptionTree<T> = IOptionTreeOption<T> | IOptionTreeOptgroup<T>;

interface IPropTreeOption<T> {
  item: IOptionTree<T>;
  makeOption: (value: T) => React.ReactElement<HTMLOptionElement>;
}

/**
 * Generate a list of <option>s from given LabeledGroup.
 */
class TreeOption<T> extends React.PureComponent<IPropTreeOption<T>, {}> {
  public render(): JSX.Element {
    const { item, makeOption } = this.props;
    if (item.type === 'group') {
      const { key, label, items } = item;
      const TOT: ReactCtor<IPropTreeOption<T>, {}> = TreeOption;
      return (
        <optgroup label={label}>
          {items.map(item => (
            <TOT key={item.key} item={item} makeOption={makeOption} />
          ))}
        </optgroup>
      );
    } else {
      const { value } = item;
      return makeOption(value);
    }
  }
}
