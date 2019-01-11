import styled from '../../util/styled';
import { WideButton } from '../../common/button';
import {
  yesColor,
  yesColorText,
  noColor,
  noColorText,
  lightBorderColor,
} from '../../common/color';
import { phone } from '../../common/media';

/**
 * Wrapper of whole page.
 */
export const PageWrapper = styled.section`
  padding: 0 20px 20px;
`;

/**
 * Wrapper of prize list.
 */
export const PrizeListWrapper = styled.div<{
  /**
   * Whether prize list is shrinked.
   */
  shrinked: boolean;
}>`
  ${({ shrinked }) =>
    shrinked
      ? `
    max-height: 200px;
    overflow-y: auto;
  `
      : ''};
`;

/**
 * Wrapper of one list of a group prize.
 */
export const PrizeGroupWrapper = styled.ul`
  display: flex;
  flex-flow: row wrap;
  justify-content: space-between;

  /* trick for last row */
  &::after {
    content: '';
    flex: auto 1 1;
  }
  li {
    display: inline-block;
  }
`;

/**
 * Wrapper of a nowprize area.
 */
export const NowPrizeWrapper = styled.div`
  background-color: #ffffff;
  ${phone`
    margin: 5px -20px;
    padding: 3px 20px 10px;
    position: sticky;
    left: 0;
    bottom: 0;
    border-top: 1px solid ${lightBorderColor};
    box-shadow: 0 -3px 2px ${lightBorderColor};
  `};
`;

/**
 * Wrapper of one prize.
 */
export const PrizeTip = styled.span<{
  selected?: boolean;
}>`
  display: inline-block;
  margin: 3px 5px;
  padding: 1px;
  border: 2px solid ${({ selected }) => (selected ? '#ee1111' : '#000000')};
  min-width: 1em;
  min-height: 1em;
  cursor: default;

  background-color: #ffffff;
  font-size: 1.2em;
  font-weight: bold;
  text-align: center;

  ${phone`
    font-size: 1em;
  `};
`;

/**
 * Tip which is conjunction.
 */
export const ConjunctionTip = styled(PrizeTip)`
  background-color: #ddffff;
`;

/**
 * Tip which is trash box.
 */
export const TrashTip = styled(PrizeTip)`
  padding: 1px 5px;
  background-color: #ffdddd;
`;

/**
 * Reminder to push save button.
 */
export const Reminder = styled.p`
  font-size: small;
  color: red;
  margin: 0.9em 0;
`;

/**
 * Save button.
 */
export const SaveButton = styled(WideButton)`
  border: none;
  background-color: ${noColor};
  color: ${noColorText};

  &:hover {
    background-color: ${yesColor};
    color: ${yesColorText};
  }
`;
