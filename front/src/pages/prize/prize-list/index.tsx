import { Prize } from '../defs';
import { Observer } from 'mobx-react';
import * as React from 'react';
import { OnePrize } from './one-prize';
import { PrizeListWrapper } from '../elements';

export interface IPropPrizeList {
  prizeGroups: Prize[][];
}
/**
 * Show the list of prizes.
 */
export const PrizeList = ({ prizeGroups }: IPropPrizeList) => {
  return (
    <Observer>
      {() =>
        prizeGroups.map((group, idx) => (
          <PrizeListWrapper key={idx}>
            {group.map(prize => (
              <OnePrize key={prize.id} prize={prize} />
            ))}
          </PrizeListWrapper>
        ))
      }
    </Observer>
  );
};
