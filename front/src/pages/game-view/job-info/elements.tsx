import styled from '../../../util/styled';
import { withProps } from '../../../util/styled';
import * as Color from 'color';
import { lightA } from '../../../styles/a';
import { phone, notPhone } from '../../../common/media';

/**
 * Wrapper of the job info component.
 * @package
 */
export const WrapperElement = withProps<{
  borderColor: Color;
  backColor: Color;
  almostHidden: boolean;
}>()(styled.div)`
  margin: 0;
  --border-color: ${props => props.borderColor.string()};
  border: 1px solid var(--border-color);
  background-color: ${props => props.backColor.string()};
  ${props => (props.almostHidden ? 'opacity: 0.15;' : '')}
`;

/**
 * Header of wrapper.
 * @package
 */
export const WrapperHeader = withProps<{
  teamColor: Color;
  textColor: Color;
  slim: boolean;
}>()(styled.div)`
  padding: 0.1em;
  background: linear-gradient(to right, ${props =>
    props.teamColor.string()}, ${props => props.teamColor.fade(0.8).string()});

  ${({ slim }) =>
    slim
      ? `
    display: flex;
    flex-flow: column nowrap;
  `
      : `
    font-size: 85%;
  `}
  color: ${props => props.textColor.string()};
`;

/**
 * wrapper of content.
 * @package
 */
export const Content = withProps<{
  slim: boolean;
}>()(styled.div)`
  display: flex;
  flex-flow: row nowrap;
  padding: ${({ slim }) => (slim ? '0.2em' : '0.4em')};
  color: black;

  a {
    ${lightA};
  }
  ${phone`
    flex-flow: column nowrap;
    font-size: 0.95em;
  `};
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

  font-size: 0.95em;
  ${notPhone`
    &:not(:first-child) {
      border-left: 1px dashed var(--border-color);
    }
  `} ${phone`
    flex: 100% 1 1;
    border-left: none;
    display: flex;
    flex-flow: row wrap;

    p {
      margin: 0 0.5em;
      line-height: 1.2;
    }
  `};
`;

/**
 * wrapper of button to open/close jobinfo form.
 */
export const JobInfoButton = styled.p`
  ${notPhone`
    display: none;
  `};
`;
