<?php

namespace App\Controller;

use App\Service\EntrepriseSearchService;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;

final class EntrepriseController extends AbstractController
{
    public function __construct(
        private readonly EntrepriseSearchService $entrepriseSearchService
    )
    {
    }

    #[Route('/api/entreprises/search', name: 'entreprise_search', methods: ['GET'])]
    public function search(Request $request): JsonResponse
    {
        $query = $request->query->get('q', '');

        if (empty($query)) {
            return $this->json(['error' => 'Le paramètre "q" est requis']);
        }

        try {
            $result = $this->entrepriseSearchService->search($query, 1, 10);

            return $this->json([
                'total' => $result->totalResults,
                'page' => $result->page,
                'results' => array_map(fn($e) => [
                    'siren' => $e->siren,
                    'nom' => $e->nomComplet,
                    'adresse' => $e->siege?->adresse,
                    'code_postal' => $e->siege?->codePostal,
                    'actif' => $e->isActif(),
                ], $result->results),
            ]);
        }
        catch (\Exception $e) {
            return $this->json([
                'error' => $e->getMessage()
            ], 500);
        }
    }

    #[Route('/api/entreprises/{siren}', name: 'entreprise_detail', methods: ['GET'])]
    public function detail(string $siren): JsonResponse
    {
        try {
            $entreprise = $this->entrepriseSearchService->findBySiren($siren);

            if (!$entreprise) {
                return $this->json(['error' => 'Entreprise non trouvée'], 404);
            }

            return $this->json([
                'siren' => $entreprise->siren,
                'nom' => $entreprise->nomComplet,
                'adresse' => $entreprise->siege?->adresse,
                'code_postal' => $entreprise->siege?->codePostal,
                'code_naf' => $entreprise->activitePrincipale,
                'actif' => $entreprise->isActif(),
            ]);
        }
        catch (\Exception $e) {
            return $this->json([
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
