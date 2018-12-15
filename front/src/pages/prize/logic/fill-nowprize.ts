import { NowPrizeType, NowPrize } from '../defs';

/**
 * Fill template with nowprize.
 */
export function fillTemplate(
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
