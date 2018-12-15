import { Prize } from '../defs';
import { phone } from '../../../common/media';

/**
 * Group of phonetics.
 * TODO how to support non-Japanese language?
 */
const phoneticGroups = [
  'あいうえお',
  'かきくけこがぎぐげご',
  'さしすせそざじずぜぞ',
  'たちつてとだぢづでど',
  'なにぬねの',
  'はひふへほばびぶべぼぱぴぷぺぽ',
  'まみむめも',
  'やゆよ',
  'らりるれろ',
  'わをん',
];

/**
 * Split prizes into groups based on phonetics.
 * @package
 */
export function splitPrizesIntoGroups(prizes: Prize[]): Prize[][] {
  // sort prizes based on phonetics.
  // TODO use Intl stuffs
  const sorted = [...prizes].sort((a, b) =>
    a.phonetic.localeCompare(b.phonetic),
  );
  const result: Prize[][] = [];
  let currentGroup: Prize[] = [];
  let currentGroupIndex = 0;
  for (const prize of sorted) {
    for (; currentGroupIndex < phoneticGroups.length; currentGroupIndex++) {
      const phonetics = phoneticGroups[currentGroupIndex];
      if (!phonetics || phonetics.includes(prize.phonetic.charAt(0))) {
        currentGroup.push(prize);
        break;
      } else {
        if (currentGroup.length > 0) {
          result.push(currentGroup);
        }
        currentGroup = [];
      }
    }
  }
  if (currentGroup.length > 0) {
    result.push(currentGroup);
  }
  return result;
}
