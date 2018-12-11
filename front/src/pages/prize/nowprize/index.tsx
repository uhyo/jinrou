import { PrizeStore } from '../store';
import { Observer } from 'mobx-react';
import * as React from 'react';
import { PrizeGroupWrapper, PrizeTip, ConjunctionTip } from '../elements';
import { NowPrizeType, NowPrize } from '../defs';

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
        const { prizeTemplate, nowprize, prizeDisplayMap } = store;
        const filled = fillTemplate(prizeTemplate, nowprize);
        return (
          <>
            <PrizeGroupWrapper>
              {filled.map((v, idx) => (
                <li key={idx}>
                  {v.type === 'prize' ? (
                    <PrizeTip>
                      {v.value != null ? prizeDisplayMap.get(v.value) : null}
                    </PrizeTip>
                  ) : (
                    <ConjunctionTip>{v.value}</ConjunctionTip>
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

/**
 * Fill template with nowprize.
 */
function fillTemplate(
  prizeTemplate: NowPrizeType[],
  nowprize: NowPrize[],
): NowPrize[] {
  const result: NowPrize[] = [];
  let nowprizeIndex = 0;
  templateLoop: for (const t of prizeTemplate) {
    for (; nowprizeIndex < nowprize.length; nowprizeIndex++) {
      const np = nowprize[nowprizeIndex];
      if (np.type !== t) {
        // this does not match.
        continue;
      }
      result.push({ ...np });
      nowprizeIndex++;
      continue templateLoop;
    }
    // fill with empty.
    if (t === 'prize') {
      result.push({
        type: 'prize',
        value: null,
      });
    } else {
      result.push({
        type: 'conjunction',
        value: '',
      });
    }
  }
  return result;
}
