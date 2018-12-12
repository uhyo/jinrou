import * as React from 'react';
import { PrizeStore } from '../store';
import { ConjunctionTip, PrizeGroupWrapper, TrashTip } from '../elements';
import {
  clickPrizeLogic,
  isConjunctionSelected,
  isTrashSelected,
  clickTrashLogic,
} from '../logic/select';
import { Observer } from 'mobx-react';
import { FontAwesomeIcon } from '../../../util/icon';

/**
 * Show a list of conjunctions.
 * TODO purify
 */
export const ConjucntionList = ({ store }: { store: PrizeStore }) => {
  return (
    <Observer>
      {() => (
        <PrizeGroupWrapper>
          {store.prizeUtil.conjunctions.map(cj => (
            <li key={cj}>
              <ConjunctionTip
                selected={isConjunctionSelected(store, cj)}
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
                onClick={() =>
                  clickPrizeLogic(store, {
                    type: 'conjunction',
                    value: cj,
                  })
                }
              >
                {cj}
              </ConjunctionTip>
            </li>
          ))}
          <TrashTip
            selected={isTrashSelected(store)}
            draggable
            onDragStart={e => {
              e.dataTransfer.setData(
                'text/x-prize-data',
                JSON.stringify({
                  type: 'trash',
                }),
              );
            }}
            onClick={() => clickTrashLogic(store)}
          >
            <FontAwesomeIcon icon="trash-alt" />
          </TrashTip>
        </PrizeGroupWrapper>
      )}
    </Observer>
  );
};
