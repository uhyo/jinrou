import styled from '../../../util/styled';
import * as Color from 'color';
import { lightA } from '../../../styles/a';
import { phone, notPhone } from '../../../common/media';
import { FlattenInterpolation, ThemedStyledProps } from 'styled-components';
import { Theme } from '../../../theme';

/**
 * Wrapper of the job info component.
 * @package
 */
export const WrapperElement = styled.div<{
  borderColor: Color;
  backColor: Color;
  almostHidden: boolean;
}>`
  margin: 0;
  --border-color: ${props => props.borderColor.string()};
  border: 1px solid var(--border-color);
  background-color: ${props => props.backColor.string()};
  ${phone`
    ${props =>
      props.almostHidden && props.theme.user.speakFormPosition === 'fixed'
        ? 'opacity: 0.15;'
        : ''}
  `};
`;

/**
 * Header of wrapper.
 * @package
 */
export const WrapperHeader = styled.div<{
  teamColor: Color;
  textColor: Color;
  slim: boolean;
}>`
  padding: 0.1em;
  background: linear-gradient(to right, ${props =>
    props.teamColor.string()}, ${props => props.teamColor.fade(0.8).string()});

  ${phone`
    font-size: ${({ slim }) =>
      slim ? 'var(--base-font-size)' : 'calc(0.85 * var(--base-font-size))'};
  `}

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
export const Content = styled.div<{
  slim: boolean;
}>`
  display: flex;
  flex-flow: row nowrap;
  padding: ${({ slim }) => (slim ? '0.2em' : '0.4em')};
  color: black;

  a {
    ${lightA};
  }
  ${phone`
    flex-flow: column nowrap;
    font-size: calc(0.95 * var(--base-font-size));
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
export const GameInfoPart = styled.div<{
  slim: boolean;
}>`
  flex: auto 0 0;
  align-self: flex-end;
  padding-left: 4px;

  ${({ slim }) => (slim ? '' : 'font-size: 0.95em;')};
  ${notPhone`
    &:not(:first-child) {
      border-left: 1px dashed var(--border-color);
    }
  `};
  ${phone`
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
  ${phone`
    button {
      font-size: 100%;
    }
  `};
`;
