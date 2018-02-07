import * as React from 'react';

import {
    LabeledGroup,
    GroupOrItem,
} from '../defs/labeled-group';

import {
    ReactCtor,
} from './react-type';

export interface IPropSelectLabeledGroup<T, L> {
    items: LabeledGroup<T, L>;
    getGroupLabel: (label: L)=> {
        key: string;
        label: string;
    };
    getOptionKey: (value: T)=> string;
    makeOption: (value: T)=> React.ReactElement<HTMLOptionElement>;
}

/**
 * Genelate a selection of given LabeledGroup.
 */
export function SelectLabeledGroup<T, L>({
    items,
    getGroupLabel,
    getOptionKey,
    makeOption,
}: IPropSelectLabeledGroup<T, L>) {
    const tree = genTree({
        items,
        getGroupLabel,
        getOptionKey,
    });

    const TOT: ReactCtor<IPropTreeOption<T>, {}> = TreeOption;

    return (<select>{
        tree.map((item)=> (
            <TOT
                key={item.key}
                item={item}
                makeOption={makeOption}
            />))
    }</select>);
}

interface IGentreeInput<T, L> {
    items: LabeledGroup<T, L>;
    getGroupLabel: (label: L)=> {
        key: string;
        label: string;
    };
    getOptionKey: (value: T)=> string;
}

function genTree<T, L>({
    items,
    getGroupLabel,
    getOptionKey,
}: IGentreeInput<T, L>): Array<IOptionTree<T>> {
    const result: Array<IOptionTree<T>> = [];
    for (const item of items) {
        if (item.type === 'group') {
            const {
                key,
                label,
            } = getGroupLabel(item.label);
            result.push({
                type: 'group',
                key: `group-${key}`,
                label,
                items: genTree({
                    items: item.items,
                    getGroupLabel,
                    getOptionKey,
                }),
            });
        } else {
            const key = getOptionKey(item.value);
            result.push({
                type: 'option',
                key: `option-${key}`,
                value: item.value,
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
    items: Array<IOptionTree<T>>
}
type IOptionTree<T> = IOptionTreeOption<T> | IOptionTreeOptgroup<T>;

interface IPropTreeOption<T> {
    item: IOptionTree<T>;
    makeOption: (value: T)=> React.ReactElement<HTMLOptionElement>;
}

/**
 * Generate a list of <option>s from given LabeledGroup.
 */
class TreeOption<T> extends React.Component<IPropTreeOption<T>, {}> {
    public render(): JSX.Element {
        const {
            item,
            makeOption,
        } = this.props;
        if (item.type === 'group') {
            const {
                key,
                label,
                items,
            } = item;
            const TOT: ReactCtor<IPropTreeOption<T>, {}> = TreeOption;
            return (<optgroup
                label={label}>{
                    items.map((item)=> (
                        <TOT
                            key={item.key}
                            item={item}
                            makeOption={makeOption}
                        />))
                }</optgroup>);
        } else {
            const {
                value,
            } = item;
            return makeOption(value);
        }
    }
}

