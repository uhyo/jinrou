import { Prize } from '../defs';
import { Observer } from 'mobx-react';
import * as React from 'react';
import { OnePrize } from './one-prize';
import { PrizeListWrapper, PrizeGroupWrapper } from '../elements';
import { PrizeStore } from '..';
import { LinkLikeButton } from '../../../common/button';
import { i18n } from '../../../i18n';

export interface IPropPrizeList {
  i18n: i18n;
  store: PrizeStore;
}
/**
 * Show the list of prizes.
 */
export const PrizeList = ({ i18n, store }: IPropPrizeList) => {
  const shrinkHandler = () => {
    store.setShrinked(!store.shrinked);
  };
  return (
    <Observer>
      {() => (
        <>
          <PrizeListWrapper shrinked={store.shrinked}>
            {store.prizeGroups.map((group, idx) => (
              <PrizeGroupWrapper key={idx}>
                {group.map(prize => (
                  <OnePrize key={prize.id} prize={prize} />
                ))}
              </PrizeGroupWrapper>
            ))}
          </PrizeListWrapper>
          <p>
            <LinkLikeButton onClick={shrinkHandler}>
              {store.shrinked
                ? i18n.t('list.unshrinkLabel')
                : i18n.t('list.shrinkLabel')}
            </LinkLikeButton>
          </p>
        </>
      )}
    </Observer>
  );
};
