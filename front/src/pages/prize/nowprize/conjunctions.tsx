import * as React from 'react';
import { PrizeStore } from '../store';
import { ConjunctionTip, PrizeGroupWrapper } from '../elements';

/**
 * Show a list of conjunctions.
 */
export const ConjucntionList = ({ store }: { store: PrizeStore }) => {
  return (
    <PrizeGroupWrapper>
      {store.prizeUtil.conjunctions.map(cj => (
        <li key={cj}>
          <ConjunctionTip>{cj}</ConjunctionTip>
        </li>
      ))}
    </PrizeGroupWrapper>
  );
};
