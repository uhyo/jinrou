import styled from '../../util/styled';
import { AppStyling } from '../../styles/phone';
import { pagePadding, formComponentsVerticalMergin } from '../../common/style';
import { mediumBorderColor } from '../../common/color';
import { phone } from '../../common/media';

export const AppWrapper = styled(AppStyling)`
  padding: 0 ${pagePadding};

  @media (min-width: 1100px) {
    display: grid;
    grid-template-columns: 1fr 500px;
    grid-template-rows: repeat(5, auto);
    grid-auto-flow: row dense;
  }
`;

export const Header = styled.h1`
  grid-column: 1 / 3;
`;

export const SectionWrapper = styled.section`
  margin: ${formComponentsVerticalMergin} 0;
  padding: 0.3em 1em;
  border: 1px solid ${mediumBorderColor};
  grid-column: 1 / 3;

  ${phone`
    border: none;
    border-bottom: 1px solid ${mediumBorderColor};
  `};
`;
