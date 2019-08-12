import styled from '../../../util/styled';
import { smallTextSize } from '../../../common/style';
import { helperTextColor, mediumBorderColor } from '../../../common/color';
import { phone } from '../../../common/media';

export const LinksWrapper = styled.div`
  display: flex;
  flex-flow: row wrap;
  margin: 0 -0.25em;
`;

export const LinkElement = styled.a<{
  long?: boolean;
}>`
  flex-basis: 9em;
  flex-grow: ${props => (props.long ? '100' : '1')};
  flex-shrink: 0;
  display: flex;
  flex-flow: column nowrap;
  align-items: center;
  margin: 0.25em;
  padding: 0.6em;
  border: 1px solid ${mediumBorderColor};
  color: currentColor;
  text-decoration: none;

  &:hover {
    background-color: rgba(0, 0, 0, 0.05);
  }

  ${phone`
    flex-basis: 6em;
`};
`;

export const LinkTitle = styled.b`
  font-size: 1.2em;
  margin: 0.4em 0;
`;

export const LinkDescription = styled.p`
  color: ${helperTextColor};
  font-size: ${smallTextSize};
  line-height: 1.5;
`;

export const LineSeparator = styled.div`
  width: 100%;

  @media (min-width: 1160px) {
    display: none;
  }
`;
