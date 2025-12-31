<?php 

declare(strict_types=1);

namespace App\Service;

use App\Dto\Entreprise;
use App\Dto\SearchResult;
use Psr\Log\LoggerInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;

/**
 * Service pour rechercher des entreprises via l'API publique.
 */
class EntrepriseSearchService
{
    private const API_BASE_URL = 'https://recherche-entreprises.api.gouv.fr';
    private const MAX_PER_PAGE = 25;

    public function __construct(
        private readonly HttpClientInterface $httpClient,
        private readonly LoggerInterface $logger,
    )
    {
    }

    public function search (
        string $query,
        int $page = 1,
        int $perPage = 10,
        array $filters = []
    ): SearchResult
    {
        try {
            $params = array_merge([
                'q' => $query,
                'page' => max(1, $page),
                'per_page' => min($perPage, self::MAX_PER_PAGE),
            ], $filters);


            $response = $this->httpClient->request('GET', self::API_BASE_URL . '/search', [
                'query' => $params,
            ]);

            $data = $response->toArray();

            $this->logger->info('Recherche entreprise effectuée', [
                'query' => $query,
                'total_results' => $data['total_results'] ?? 0,
            ]);

            return SearchResult::fromArray($data);
        }
        catch(\Exception $e) {
            $this->logger->error('Erreur lors de la recherche entreprise', [
                'query' => $query,
                'error' => $e->getMessage(),
            ]);

            throw new \RuntimeException(
                sprintf('Erreur lors de la recherche entreprise : %s', $e->getMessage()),
                0,
                $e
            );
        }
    }

    /**
     * Trouve une entreprise par son SIREN
     */
    public function findBySiren(string $siren): ?Entreprise
    {
        // Nettoyer le SIREN (enlever espaces, tirets)
        $siren = preg_replace('/[^0-9]/', '', $siren);

        if (strlen($siren) !== 9) {
            throw new \InvalidArgumentException('Le SIREN doit contenir exactement 9 chiffres');
        }

        $result = $this->search($siren, 1, 1);

        if(!$result->hasResults()) {
            return null;
        }

        /** @var Entreprise $entreprise */
        $entreprise = $result->getFirstResult();

        // Vérifier que le SIREN correspond exactement
        if($entreprise && $entreprise->siren === $siren) {
            return $entreprise;
        }

        return null;
    }

    /**
     * Trouve une entreprise par son code postal
     */
    public function searchByCodePostal(
        string $codePostal,
        int $page = 1,
        int $perPage = 10
    ): SearchResult 
    {
        return $this->search('', $page, $perPage, [
            'code_postal' => $codePostal,
        ]);
    }
}