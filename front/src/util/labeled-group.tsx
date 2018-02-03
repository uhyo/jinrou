import * as React from 'react';

import {
    LabeledGroup,
    GroupOrItem,
} from '../defs/labeled-group';

export interface IPropOptgroups<T, L> {
    items: LabeledGroup<T, L>;
    getGroupLabel: (label: L)=> {
        key: string;
        label: string;
    };
    getOptionKey: (value: T)=> string;
    makeOption: (value: T)=> React.ReactElement<HTMLOptionElement>;
}
/**
 * Generate a list of <option>s from given LabeledGroup.
 */
export function Optgroups<T, L>({
    items,
    getGroupLabel,
    getOptionKey,
    makeOption,
}: IPropOptgroups<T, L>): React.ReactFragment {
    return <>{
        items.map(obj=>{
            if (obj.type === 'group'){
                const {
                    key,
                    label,
                } = getGroupLabel(obj.label);
                return (<optgroup key={`optgroup-${key}`} label={label}>{
                    Optgroups({
                        items: obj.items,
                        getGroupLabel,
                        getOptionKey,
                        makeOption,
                    })
                }</optgroup>);
            } else {
                const key = getOptionKey(obj.value);
                return (<React.Fragment key={`option-${key}`}>{
                    makeOption(obj.value)
                }</React.Fragment>);
            }
        })
    }</>;
}
