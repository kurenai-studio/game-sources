import { Field, SelectField } from "../ui";
import type { Filters } from "./use-players";

/** Search, status and sort for the player list. */
export function PlayerFilters({
  filters,
  onChange,
}: {
  filters: Filters;
  onChange: (next: Partial<Filters>) => void;
}) {
  return (
    <form
      role="search"
      aria-label="Filter players"
      onSubmit={(e) => e.preventDefault()}
      className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
    >
      <Field
        label="Search"
        id="player-search"
        type="search"
        value={filters.q}
        onChange={(e) => onChange({ q: e.target.value })}
        placeholder="Email or name"
        autoComplete="off"
      />
      <SelectField
        label="Status"
        id="player-status"
        value={filters.status}
        onChange={(e) => onChange({ status: e.target.value as Filters["status"] })}
      >
        <option value="">All</option>
        <option value="ACTIVE">Active</option>
        <option value="SUSPENDED">Suspended</option>
      </SelectField>
      <SelectField
        label="Sort"
        id="player-sort"
        value={filters.sort}
        onChange={(e) => onChange({ sort: e.target.value as Filters["sort"] })}
      >
        <option value="lastActive">Last active</option>
        <option value="points">Points</option>
        <option value="cleared">Levels cleared</option>
        <option value="created">Joined</option>
        <option value="email">Email</option>
      </SelectField>
      <SelectField
        label="Order"
        id="player-order"
        value={filters.order}
        onChange={(e) => onChange({ order: e.target.value as Filters["order"] })}
      >
        <option value="desc">Highest or newest first</option>
        <option value="asc">Lowest or oldest first</option>
      </SelectField>
    </form>
  );
}
