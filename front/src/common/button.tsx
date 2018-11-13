import styled from 'styled-components';

/**
 * Normal button which has proper margin around.
 */
export const NormalButton = styled.button`
  margin: 0.8em;
`;

/**
 * Button which stretches to whole width.
 */
export const WideButton = styled.button`
  appearance: none;
  width: -moz-available;
  width: -webkit-fill-available;
  width: stretch;

  border: 1px solid rgba(32, 32, 32, 0.8);
  padding: 0.5em;

  font-size: 1.1em;

  background-color: rgba(255, 255, 255, 0.1);

  :hover {
    background-color: rgba(255, 255, 255, 0.6);
  }
`;
