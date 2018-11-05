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
  margin: 0;
  --border-color: ${props => props.borderColor.string()};
  border: 1px solid var(--border-color);
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
  display: flex;
  flex-flow: row nowrap;
  padding: 8px;
  color: black;

  a {
    ${lightA};
  }
`;

/**
 * Wrapper of role info.
 */
export const RoleInfoPart = styled.div`
  flex: auto 0 1;
  padding-right: 4px;
`;

/**
 * Wrapper of game info.
 */
export const GameInfoPart = styled.div`
  flex: auto 0 0;
  align-self: flex-end;
  padding-left: 4px;
  &:not(:first-child) {
    border-left: 1px dashed var(--border-color);
  }

  font-size: 0.9em;
`;
