import * as React from 'react';
import { PrizeStore } from '../store';
import { ConjunctionTip, PrizeGroupWrapper } from '../elements';

/**
 * Show a list of conjunctions.
 * TODO purify
 */
export const ConjucntionList = ({ store }: { store: PrizeStore }) => {
  return (
    <PrizeGroupWrapper>
      {store.prizeUtil.conjunctions.map(cj => (
        <li key={cj}>
          <ConjunctionTip
            draggable
            onDragStart={e => {
              e.dataTransfer.setData('text/plain', cj);
              e.dataTransfer.setData(
                'text/x-prize-data',
                JSON.stringify({
                  type: 'conjunction',
                  value: cj,
                }),
              );
            }}
          >
            {cj}
          </ConjunctionTip>
        </li>
      ))}
    </PrizeGroupWrapper>
  );
};
