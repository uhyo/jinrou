import { PrizeStore } from '../store';
import { Observer } from 'mobx-react';
import * as React from 'react';
import { PrizeGroupWrapper, PrizeTip, ConjunctionTip } from '../elements';
import { NowPrizeType, NowPrize } from '../defs';
import { isNowprizeSelected, clickNowPrizeLogic } from '../logic/select';

export interface IPropNowPrize {
  store: PrizeStore;
}
/**
 * Show an editor of current prize.
 */
export const NowPrizeList = ({ store }: IPropNowPrize) => {
  return (
    <Observer>
      {() => {
        const { nowprize, prizeDisplayMap } = store;
        const onDragStart = (idx: number, e: React.DragEvent) => {
          const val = store.nowprize[idx].value;
          if (val) {
            e.dataTransfer.setData('text/plain', val);
            e.dataTransfer.setData(
              'text/x-prize-data',
              JSON.stringify({
                type: 'now',
                index: idx,
              }),
            );
          } else {
            e.preventDefault();
          }
        };
        const onDragEnter = (e: React.DragEvent) => {
          e.preventDefault();
        };
        const onDragOver = (e: React.DragEvent) => {
          e.dataTransfer.dropEffect = 'copy';
          e.preventDefault();
        };
        const onDrop = (idx: number, e: React.DragEvent) => {
          // prevent jumping in Firefox.
          e.preventDefault();
          const data = e.dataTransfer.getData('text/x-prize-data');
          if (data === '') {
            // not related.
            return;
          }
          try {
            const prize = JSON.parse(data);
            if (prize.type === 'trash') {
              store.deleteNowPrize(idx);
            } else if (prize.type === 'now') {
              // now-now transfer.
              const from = store.nowprize[prize.index];
              const to = store.nowprize[idx];
              store.updateNowPrize(idx, from);
              store.updateNowPrize(prize.index, to);
            } else {
              store.updateNowPrize(idx, prize);
            }
          } catch (e) {
            // !?
            console.error('JSON parse error', e);
          }
        };
        return (
          <>
            <PrizeGroupWrapper>
              {nowprize.map((v, idx) => (
                <li key={idx}>
                  {v.type === 'prize' ? (
                    <PrizeTip
                      selected={isNowprizeSelected(store, idx)}
                      draggable
                      onDragStart={onDragStart.bind(null, idx)}
                      onDragEnter={onDragEnter}
                      onDragOver={onDragOver}
                      onDrop={onDrop.bind(null, idx)}
                      onClick={() => clickNowPrizeLogic(store, idx)}
                    >
                      {v.value != null ? prizeDisplayMap.get(v.value) : null}
                    </PrizeTip>
                  ) : (
                    <ConjunctionTip
                      selected={isNowprizeSelected(store, idx)}
                      draggable
                      onDragStart={onDragStart.bind(null, idx)}
                      onDragEnter={onDragEnter}
                      onDragOver={onDragOver}
                      onDrop={onDrop.bind(null, idx)}
                      onClick={() => clickNowPrizeLogic(store, idx)}
                    >
                      {v.value}
                    </ConjunctionTip>
                  )}
                </li>
              ))}
            </PrizeGroupWrapper>
          </>
        );
      }}
    </Observer>
  );
};
