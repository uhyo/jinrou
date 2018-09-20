import { RoleCategoryDefinition } from '../../../defs/category-definition';
import { CastingStore } from '../store';

/**
 * Generate a query from store.
 */
export function getQuery(
  roles: string[],
  categories: RoleCategoryDefinition[],
  store: CastingStore,
): Record<string, string> {
  const {
    actualPlayersNumber,
    jobNumbers,
    jobInclusions,
    categoryNumbers,
    rules,
    currentCasting,
  } = store;
  const result: Record<string, string> = {};
  // Add role param.
  for (const role of roles) {
    const v = jobNumbers[role] || 0;
    result[role] = String(v);
  }
  // Add category number param.
  for (const { id } of categories) {
    const v = categoryNumbers.get(id) || 0;
    result[`category_${id}`] = String(v);
  }
  // Add job inclusion param.
  for (const role of roles) {
    const include = jobInclusions.get(role);
    result[`job_use_${role}`] = include !== false ? 'on' : '';
  }
  // Add rule param.
  for (const [rule, value] of rules) {
    result[rule] = value;
  }
  // Add player number param,
  // scapegoat should not be added here.
  result['number'] = String(actualPlayersNumber);
  // Add `jobrule` param.
  result['jobrule'] = currentCasting.id;
  return result;
}
