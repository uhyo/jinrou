import styled from '../../../util/styled';
import { SectionWrapper } from '../elements';

export const NewsSectionWrapper = styled(SectionWrapper)<{
  isLoading: boolean;
}>`
  opacity: ${({ isLoading }) => (isLoading ? '0.3' : '1')};
`;

export const NewsTable = styled.table``;
