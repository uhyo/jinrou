import styled from '../../util/styled';

/**
 * Wrapper of whole page.
 */
export const PageWrapper = styled.section`
  padding: 0 20px;
`;

/**
 * Wrapper of list of prize.
 */
export const PrizeListWrapper = styled.ul`
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
