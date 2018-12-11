import styled, { withProps } from '../../util/styled';

/**
 * Wrapper of whole page.
 */
export const PageWrapper = styled.section`
  padding: 0 20px;
`;

/**
 * Wrapper of prize list.
 */
export const PrizeListWrapper = withProps<{
  /**
   * Whether prize list is shrinked.
   */
  shrinked: boolean;
}>()(styled.ul)`
  ${({ shrinked }) =>
    shrinked
      ? `
    max-height: 200px;
    overflow-y: auto;
  `
      : ''}
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
 * Wrapper of one prize.
 */
export const PrizeTip = styled.span`
  display: inline-block;
  margin: 3px 5px;
  padding: 1px;
  border: 2px solid black;

  background-color: #ffffff;
  font-size: 1.2em;
  font-weight: bold;
`;
