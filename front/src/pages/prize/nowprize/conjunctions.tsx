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
import { I18n } from '../../../i18n';

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
          <I18n>
            {t => {
              // TODO: similar stuff at two places
              const onDragEnter = (e: React.DragEvent) => {
                e.preventDefault();
              };
              const onDragOver = (e: React.DragEvent) => {
                e.dataTransfer.dropEffect = 'copy';
                e.preventDefault();
              };
              const onDrop = (e: React.DragEvent) => {
                // prevent jumping in Firefox.
                e.preventDefault();
                const data = e.dataTransfer.getData('text/x-prize-data');
                if (data === '') {
                  // not related.
                  return;
                }
                try {
                  const prize = JSON.parse(data);
                  if (prize.type === 'now') {
                    // delete now prize.
                    store.deleteNowPrize(prize.index);
                  }
                } catch (e) {
                  // !?
                  console.error('JSON parse error', e);
                }
              };
              return (
                <TrashTip
                  title={t('edit.trash')}
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
                  onDragEnter={onDragEnter}
                  onDragOver={onDragOver}
                  onDrop={onDrop}
                  onClick={() => clickTrashLogic(store)}
                >
                  <FontAwesomeIcon icon="trash-alt" />
                </TrashTip>
              );
            }}
          </I18n>
        </PrizeGroupWrapper>
      )}
    </Observer>
  );
};
