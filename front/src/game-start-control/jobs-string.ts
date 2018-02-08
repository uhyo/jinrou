/**
 * Make a string representing given jobNumbers.
 */
export function makeJobsString(roles: string[], jobNumbers: Record<string, number>): string {
    // TODO
    return roles.map((id)=> {
        const val = jobNumbers[id] || 0;
        if (val > 0) {
            return `${id}: ${val}`;
        } else {
            return '';
        }
    }).join(' ');
}
