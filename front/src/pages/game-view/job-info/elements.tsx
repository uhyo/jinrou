import styled from '../../../util/styled';
import { withProps } from '../../../util/styled';
import * as Color from 'color';
import { lightA } from '../../../styles/a';

/**
 * Wrapper of the job info component.
 * @package
 */
export const WrapperElement = withProps<{
  borderColor: Color;
  backColor: Color;
}>()(styled.div)`
  margin: 5px 0;
  border: 1px solid ${props => props.borderColor.string()};
  background-color: ${props => props.backColor.string()};
`;

/**
 * Header of wrapper.
 * @package
 */
export const WrapperHeader = withProps<{
  teamColor: Color;
  textColor: Color;
}>()(styled.div)`
  padding: 3px;
  background: linear-gradient(to right, ${props =>
    props.teamColor.string()}, ${props => props.teamColor.fade(0.8).string()});

  font-size: 85%;
  color: ${props => props.textColor.string()};
`;

/**
 * wrapper of content.
 * @package
 */
export const Content = styled.div`
  padding: 8px;
  color: black;

  a {
    ${lightA};
  }
`;
