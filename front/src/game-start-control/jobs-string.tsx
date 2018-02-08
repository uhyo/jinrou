import * as React from 'react';
import {
    i18n,
    I18n,
    TranslationFunction,
} from '../i18n';

import {
    InlineWarning,
} from '../common/warning';

export interface IPropJobsString {
    i18n: i18n;
    jobNumbers: Record<string, number>;
    roles: string[];
}
/**
 * String representing given jobNumbers.
 */
export function JobsString({
    i18n,
    jobNumbers,
    roles,
}: IPropJobsString) {
    return (<I18n i18n={i18n}>{
        (t)=> {
            return roles.map((id)=> {
                const val = jobNumbers[id] || 0;
                if (val > 0) {
                    return (<span key={id}>{t(`roles:jobname.${id}`)}: {val} </span>);
                } else {
                    return <React.Fragment key={id} />;
                }
            })
        }
    }</I18n>);
}

export interface IPropPlayerNumberError {
    t: TranslationFunction;
    minNumber?: number;
    maxNumber?: number;
}

/**
 * Player number is not enough.
 */
export function PlayerNumberError({
    t,
    minNumber,
    maxNumber,
}: IPropPlayerNumberError) {
    if (minNumber != null) {
        return (<InlineWarning>{
            t('game_client:gamestart.info.playerTooFew', {
                count: minNumber,
            })
        }</InlineWarning>);
    } else if (maxNumber != null) {
        return (<InlineWarning>{
            t('game_client:gamestart.info.playerTooMany', {
                count: maxNumber,
            })
        }</InlineWarning>);
    } else {
        return null;
    }
}
